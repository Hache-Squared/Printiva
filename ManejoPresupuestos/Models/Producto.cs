using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Producto
    {
        public int ProductoId { get; set; }

        [Required]
        [StringLength(200)]
        public string Nombre { get; set; }

        [Required]
        public int ProductoCategoriaId { get; set; }

        public string ProductoCategoria { get; set; }

        public string SKU { get; set; }

        public decimal? PrecioSugerido { get; set; }

        public bool EstaActivo { get; set; }
    }
}
