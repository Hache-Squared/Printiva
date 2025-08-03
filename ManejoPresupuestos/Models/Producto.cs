using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Producto
    {
        public int ProductoId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(maximumLength: 100, ErrorMessage = "No puede ser mayor a {1} caracteres")]
        public string Nombre { get; set; }
        [Display(Name = "Categoría")]
        public int ProductoCategoriaId { get; set; }
        public string ProductoCategoria { get; set; }
        public string SKU { get; set; }
    }
}
