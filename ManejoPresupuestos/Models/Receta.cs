using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Receta
    {
        public int RecetaId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(maximumLength: 100, ErrorMessage = "No puede ser mayor a {1} caracteres")]
        public string Nombre { get; set; }

        public int[] InventariosIds { get; set; }
    }

    public class RecetaRow
    {
        public int RecetaId { get; set; }
        public string Nombre { get; set; } = "";
        public bool EstaActivo { get; set; }
        public string? TiempoImpresion { get; set; }
        public bool IsSelected { get; set; }
    }

    public class AsignarRecetaItemViewModel
    {
        [Required] public int ProduccionItemId { get; set; }
        [Required] public int RecetaId { get; set; }
    }

    public class ReplicarRecetaViewModel
    {
        public int RecetaIdOrigen { get; set; }
        public string? NombreNuevo { get; set; } // opcional
    }

    public class DesactivarRecetaViewModel
    {
        public int RecetaId { get; set; }
    }

}
